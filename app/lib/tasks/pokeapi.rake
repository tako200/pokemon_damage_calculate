namespace :pokeapi do
  desc "PokeAPI から技とポケモンを取り込む（技 → ポケモンの順。LIMIT=10 で件数を絞れる）"
  task import: %i[import_moves import_pokemons]

  desc "PokeAPI から技を取り込む"
  task import_moves: :environment do
    result = PokeApi::MoveImporter.new(logger: ActiveSupport::Logger.new($stdout)).call(limit: ENV["LIMIT"].presence&.to_i)

    puts "Moves imported: #{result[:imported]}"
    puts "Moves failed: #{result[:failed].join(", ")}" if result[:failed].any?
  end

  desc "PokeAPI からポケモンと覚える技を取り込む（先に import_moves が必要）"
  task import_pokemons: :environment do
    result = PokeApi::PokemonImporter.new(logger: ActiveSupport::Logger.new($stdout)).call(limit: ENV["LIMIT"].presence&.to_i)

    puts "Pokemons imported: #{result[:imported]}"
    puts "Pokemons excluded: #{result[:excluded]} (removed from DB: #{result[:removed]})"
    puts "Pokemons failed: #{result[:failed].join(", ")}" if result[:failed].any?
  end
end
