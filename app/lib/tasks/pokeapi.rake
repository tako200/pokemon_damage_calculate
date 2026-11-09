namespace :pokeapi do
  desc "PokeAPI からポケモンを取り込む（LIMIT=10 で件数を絞れる）"
  task import: :environment do
    limit = ENV["LIMIT"].presence&.to_i
    logger = ActiveSupport::Logger.new($stdout)

    result = PokeApi::Importer.new(logger: logger).call(limit: limit)

    puts "Imported: #{result[:imported]}"
    puts "Failed: #{result[:failed].join(", ")}" if result[:failed].any?
  end
end
