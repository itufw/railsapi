# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $('.wine-list-product').on "click", ->
    $.ajax
      url: "/activity/add_note"
      type: "GET"
      dataType: "script"
      data:{
         product_selected: $(this).attr('id')
      };
  $(".save-as-sample").on "click", ->
    $.ajax
      url: "/activity/add_note"
      type: "GET"
      dataType: "script"
      data:{
        sample_products: $('.hidden_samples').val()
      };
  $('.selected_customer').on "change", ->
    $.ajax
      url: "/activity/selected_customer"
      type: "GET"
      dataType: "script"
      data:{
        customer_id: $('.selected_customer').attr('customer_id')
      };
