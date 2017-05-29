# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $('.add_row_product').on "click", ->
    $.ajax
      url: "/activity/add_note"
      type: "GET"
      dataType: "script"
      data:{
        product_search_text: $("#product_search").val()
      };

  $('.activity-customers').on "click", ->
    $.ajax
      url: "/activity/add_note"
      type: "GET"
      dataType: "script"
      data:{
        customer_search_text: $("#customer_search").val()
      };

  $('.wine-list-product').on "click", ->
    $.ajax
      url: "/activity/add_note"
      type: "GET"
      dataType: "script"
      data:{
        product_selected: $(this).attr('id')
      };
