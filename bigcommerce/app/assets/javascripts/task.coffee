# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $(".function_selection").on "change", ->
    $.ajax
      url: "/task/add_task"
      type: "GET"
      dataType: "script"
      data:{
        selected_function: $('.function_selection option:selected').val(),
        selected_staff: $('.staff_selection option:selected').val()
      };
  $(".staff_selection").on "change", ->
    $.ajax
      url: "/task/add_task"
      type: "GET"
      dataType: "script"
      data:{
        selected_function: $('.function_selection option:selected').val(),
        selected_staff: $('.staff_selection option:selected').val()
      };
  $(".function_selection_task").on "change", ->
    $.ajax
      url: "/task/add_task"
      type: "GET"
      dataType: "script"
      data:{
        selected_function_task: $('.function_selection_task option:selected').val(),
        selected_staff_task: $('.staff_selection_task option:selected').val()
      }
  $(".staff_selection_task").on "change", ->
    $.ajax
      url: "/task/add_task"
      type: "GET"
      dataType: "script"
      data:{
        selected_function_task: $('.function_selection_task option:selected').val(),
        selected_staff_task: $('.staff_selection_task option:selected').val()
      };
