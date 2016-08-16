// $(document).on('page:change', function() {
	
// 	$("#products-view-button").click(function() {
// 		$(".orders-view").css("display", "none")

// 		$(".products-view").css("display", "block")
// 		$("#products-view-table").css("display", "table")

// 		$("#orders-view-button").css("background-color", "#e7e7e7")
// 		$("#orders-view-button").css("color", "black")

// 		$("#products-view-button").css("background-color", "#4CAF50")
// 		$("#products-view-button").css("color", "white")

// 	});
	
// 	$("#orders-view-button").click(function() {

// 		$(".products-view").css("display", "none")

// 		$(".orders-view").css("display", "block")
// 		$("#orders-view-table").css("display", "table")

// 		$("#products-view-button").css("background-color", "#e7e7e7")
// 		$("#products-view-button").css("color", "black")

// 		$("#orders-view-button").css("background-color", "#4CAF50")
// 		$("#orders-view-button").css("color", "white")
		
// 	});
// })

$(document).on('page:change', function() {

	$("#products-view-button").click(function() {
		$(".orders-view").removeClass("default")
		$(".orders-view").addClass("not-default")

		$(".products-view").removeClass("not-default")
		$(".products-view").addClass("default")
	});

	$("#orders-view-button").click(function() {
		$(".orders-view").removeClass("not-default")
		$(".orders-view").addClass("default")

		$(".products-view").removeClass("default")
		$(".products-view").addClass("not-default")
	});


})
