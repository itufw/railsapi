# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $('.activity-customers').on "click", ->
    $.ajax
      url: "/activity/add_note"
      type: "GET"
      dataType: "script"
      data:{
        customer_search_text: $("#customer_search").val()
      };

  $('.activity-staffs').on "click", ->
    $.ajax
      url: "/activity/add_activity"
      type: "GET"
      dataType: "script"
      data:{
        staff_search_text: $("#staff_search").val()
      };

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
