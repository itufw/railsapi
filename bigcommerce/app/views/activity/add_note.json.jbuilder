json.array!(@products) do |product|
  json.name product.name
  json.price product.price
end
