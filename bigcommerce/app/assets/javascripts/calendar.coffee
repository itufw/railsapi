# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $(".calendar-date").on "click", ->
    $.ajax
      url: "/calendar/local_calendar"
      type: "GET"
      dataType: "script"
      data:{
        calendar_date_selected: $(this).attr('date'),
        calendar_staff_selected: $(this).attr('staff-id')
      };
  $(".calendar-staff-selector").on "click", ->
    $.ajax
      url: "/calendar/local_calendar"
      type: "GET"
      dataType: "script"
      data:{
        calendar_date_selected: '2017-05-01',
        calendar_staff_selected: $(this).attr('staff-id')
      };
