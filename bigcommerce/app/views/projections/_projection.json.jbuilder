json.extract! projection, :id, :customer_id, :customer_name, :q_lines, :q_bottles, :q_avgluc, :quarter, :recent, :sale_rep_id, :sale_name_name, :created_by, :created_by_id, :created_at, :updated_at
json.url projection_url(projection, format: :json)