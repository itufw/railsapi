require 'activity_helper.rb'

# The replacement of task controller
class ActivityController < ApplicationController
  before_action :confirm_logged_in

  autocomplete :product, :name, full: true

  include ActivityHelper

  # insert notes
  # following Dropbox -> pages -> Activity
  def add_note
    @customers, @contacts \
      = customer_search(params)

    # activity helper -> get the functions/subjects/methods from json request
    @function, @subjects, @methods, @function_role, @promotion, @portfolio \
      = function_search(params)
    # @products = product_search
    @note = Task.new

    # TEST VERSION
    @products = Product.sample_products(35, 20)

    @search_text = params[:product_search_text] || nil

    @product_selected = params[:product_selected] || nil
    # production version
    # @products = Product.sample_products(session[:user_id], 10)
  end

end

# Auto insert for product notes
# $('#sample-20').click(function(){
#   <% @products.each do |product|%>
#     if($('#tr_<%=product.id%>').length == 0){
#       $('#product_table').append([
#         '<tr id="tr_<%=product.id%>">',
#             '<td><%= product.id%></td>',
#             '<td><%= product.name%></td>',
#             '<td><%= product.calculated_price%></td>',
#             '<td><%= text_field_tag 'price '+product.id.to_s, product.calculated_price, placeholder: 'Price'%></td>',
#             '<td><%= text_field_tag 'note '+product.id.to_s, ''%></td>',
#             '<td><%= check_box_tag 'buy_wine[]', product.id%> Yes </td>',
#             '<td>Star</td>',
#             '<td><i class="glyphicon glyphicon-remove remove_row" title="remove"></i></td>',
#         '</tr>'
#         ].join(''));
#         $('.remove_row').click(function(){
#           $(this).parent().parent().remove();
#         });
#       }
#   <% end %>
# });


  #
