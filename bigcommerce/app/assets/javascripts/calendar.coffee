# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $(".staff-select").on "click", ->
    $.ajax
      url: "/calendar/local_calendar"
      type: "GET"
      dataType: "script"
      data:{
        calendar_staff_selected: $(this).find('a').attr('staff_id')
      };
