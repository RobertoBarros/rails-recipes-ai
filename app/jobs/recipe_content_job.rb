class RecipeContentJob < ApplicationJob
  queue_as :default

  def perform(recipe)
    client = OpenAI::Client.new
    chaptgpt_response = client.chat(parameters: {
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: "Give me a simple recipe for #{recipe.name} with the ingredients #{recipe.ingredients}. Give me only the text of the recipe, without any of your own answer like 'Here is a simple recipe'."}]
    })
    new_content = chaptgpt_response["choices"][0]["message"]["content"]

    recipe.content = new_content

    response = client.images.generate(parameters: {
      prompt: "A recipe image of #{recipe.name}", size: "256x256"
    })

    url = response["data"][0]["url"]
    file =  URI.parse(url).open

    recipe.photo.purge if recipe.photo.attached?
    recipe.photo.attach(io: file, filename: "ai_generated_image.jpg", content_type: "image/png")
    recipe.save!

    Turbo::StreamsChannel.broadcast_replace_to(
      'recipe-stream',
      target: recipe,
      partial: 'recipes/recipe',
      locals: { recipe: recipe })
  end
end
