function createCookie(name, value) {
	localStorage.setItem(name, value);
}

function readCookie(name) {
	return localStorage.getItem(name);
}

function isDarkTheme() {
	return document.querySelector("html").classList.contains("dark-theme");
}

function toggleTheme() {
	const htmlTag = document.querySelector("html");
	let isDark = isDarkTheme();
	if (isDark) {
		htmlTag.classList.remove("dark-theme");
	} else {
		htmlTag.classList.add("dark-theme");
	}
	isDark = isDarkTheme();
	localStorage.theme = isDark ? "dark" : "light";
}

function toggleInherited(el) {
	var toggle = $(el).closest(".toggle");
	toggle.toggleClass("toggle-on");
	if (toggle.hasClass("toggle-on")) {
		$("i", toggle).removeClass("fa-folder").addClass("fa-folder-open");
	} else {
		$("i", toggle).addClass("fa-folder").removeClass("fa-folder-open");
	}
	return false;
}

function toggleCollapsed(el) {
	var toggle = $(el).closest(".expando");
	toggle.toggleClass("expanded");

	if (toggle.hasClass("expanded")) {
		$(toggle).find("i").first().removeClass("fa-folder").addClass("fa-folder-open");
	} else {
		$(toggle).find("i").first().addClass("fa-folder").removeClass("fa-folder-open");
	}
	updateTreeState();
	return false;
}

function updateTreeState() {
	var states = [];
	$("#nav .expando").each(function (i, e) {
		states.push($(e).hasClass("expanded") ? 1 : 0);
	});
	var treeState = JSON.stringify(states);
	createCookie("treeState", treeState);
}

function setPlatform(platform) {
	createCookie("platform", platform);
	$("#select-platform").val(platform);

	var styles = ".platform { display:none }";
	var platforms = dox.platforms;
	if (platform == "flash" || platform == "js") {
		styles += ".package-sys { display:none; } ";
	}
	for (var i = 0; i < platforms.length; i++) {
		var p = platforms[i];
		if (platform == "sys") {
			if (p != "flash" && p != "js") {
				styles += ".platform-" + p + " { display:inherit } ";
			}
		}
		else {
			if (platform == "all" || p == platform) {
				styles += ".platform-" + p + " { display:inherit } ";
			}
		}
	}

	if (platform != "flash" && platform != "js") {
		styles += ".platform-sys { display:inherit } ";
	}

	$("#dynamicStylesheet").text(styles);
}

$(document).ready(function () {
	$("#nav").html(navContent);
	var treeState = readCookie("treeState");

	$("#nav .expando").each(function (i, e) {
		$("i", e).first().addClass("fa-folder").removeClass("fa-folder-open");
	});

	$(".treeLink").each(function () {
		this.href = this.href.replace("::rootPath::", dox.rootPath);
	});

	if (treeState != null) {
		var states = JSON.parse(treeState);
		$("#nav .expando").each(function (i, e) {
			if (states[i]) {
				$(e).addClass("expanded");
				$("i", e).first().removeClass("fa-folder").addClass("fa-folder-open");
			}
		});
	}
	$("head").append("<style id='dynamicStylesheet'></style>");

	setPlatform(readCookie("platform") == null ? "all" : readCookie("platform"));

	$("#search").on("input", function (e) {
		searchQuery(e.target.value);
	});
	$(document).bind("keyup keydown", function (e) {
		if (e.ctrlKey && e.keyCode == 80) { // ctrl + p
			$("#search").focus();
			return false;
		}
		return true;
	});
	function getItems() {
		return $("#search-results-list a").toArray();
	}
	$("#search").bind("keyup", function (e) {
		switch (e.keyCode) {
			case 27: // escape
				searchQuery("");
				$("#search").val("")
				$("#search").blur();
				return false;

			case 13: // enter
				var items = getItems();
				for (i = 0; i < items.length; i++) {
					var item = $(items[i]);
					if (item.hasClass("selected")) {
						window.location = items[i].href;
						break;
					}
				}
				return false;
		}
	});
	$("#search").bind("keydown", function (e) {
		function mod(a, b) {
			var r = a % b;
			return r < 0 ? r + b : r;
		}
		function changeSelection(amount) {
			var previousSelection = null;
			var items = getItems();
			for (i = 0; i < items.length; i++) {
				var item = $(items[i]);
				if (item.hasClass("selected")) {
					item.removeClass("selected");
					previousSelection = i;
					break;
				}
			}
			var newSelection = mod(previousSelection + amount, items.length);
			$(items[newSelection]).addClass("selected");
			items[newSelection].scrollIntoView(false);
		}
		switch (e.keyCode) {
			case 38: // up
				changeSelection(-1);
				return false;

			case 40: // down
				changeSelection(1);
				return false;

			case 13: // enter
				return false;
		}
	});

	$("#select-platform").selectpicker().on("change", function (e) {
		var value = $(":selected", this).val();
		setPlatform(value);
	});

	$("#nav a").each(function () {
		if (this.href == location.href) {
			$(this.parentElement).addClass("active");
		}
	});

	$("a.expand-button").click(function (e) {
		var container = $(this).parent().next();
		container.toggle();
		$("i", this).removeClass("fa-folder-open")
			.removeClass("fa-folder")
			.addClass(container.is(":visible") ? "fa-folder-open" : "fa-folder");
		return false;
	});

	// Because there is no CSS parent selector
	$("code.prettyprint").parents("pre").addClass("example");
});

function searchQuery(query) {
	$("#searchForm").removeAttr("action");
	query = query.replace(/[&<>"']/g, "");
	if (!query || query.length < 2) {
		$("#nav").removeClass("searching");
		$("#nav li").each(function (index, element) {
			var e = $(element);
			e.css("display", "");
		});
		$("#nav ul:first-child").css("display", "block");
		$("#search-results-list").css("display", "none");
		return;
	}
	var queryParts = query.toLowerCase().split(" ");
	var listItems = [];
	var bestMatch = 200;
	$("#nav").addClass("searching");
	$("#nav ul:first-child").css("display", "none");
	$("#nav li").each(function (index, element) {
		var e = $(element);
		if (!e.hasClass("expando")) {
			var content = e.attr("data_path");
			var score = searchMatch(content, queryParts);
			if (score >= 0) {
				if (score < bestMatch) {
					var url = dox.rootPath + e.attr("data_path").split(".").join("/") + ".html";
					$("#searchForm").attr("action", url);
					// best match will be form action
					bestMatch = score;
				}

				var elLink = $("a", element);
				// highlight matched parts
				var elLinkContent = elLink.text().replace(new RegExp("(" + queryParts.join("|").split(".").join("|") + ")", "ig"), "<strong>$1</strong>");
				var liStyle = (score == 0) ? ("font-weight:bold") : "";
				listItems.push({ score: score, item: "<li style='" + liStyle + "'><a href='" + elLink.attr("href") + "'>" + elLinkContent + "</a></li>" });
			}
		}
	});
	if ($("#search-results-list").length == 0) {
		// append to nav
		$("#nav").parent().append("<ul id='search-results-list' class='nav nav-list'></ul>");
	}
	listItems.sort(function (x, y) { return x.score - y.score; }); // put in order
	$("#search-results-list").css("display", "block").html(listItems.map(function (x) { return x.item; }).join(""));
	// pre-select the first item
	$("#search-results-list a").removeClass("selected");
	$("#search-results-list a:first").addClass("selected");
}

function match(textParts, query) {
	var queryParts = query.split(".");
	if (queryParts.length == 1) {
		var queryPart = queryParts[0];
		for (var i = 0; i < textParts.length; ++i) {
			var textPart = textParts[i];
			if (textPart.indexOf(queryPart) > -1) {
				// We don't want to match the same part twice, so let's remove it
				textParts[i] = textParts[i].split(queryPart).join("");
				return textPart.length - queryPart.length;
			}
		}
	} else {
		var offset = -1;
		outer:
		while (true) {
			++offset;
			if (queryParts.length + offset > textParts.length) {
				return -1;
			}
			var scoreSum = 0;
			for (var i = 0; i < queryParts.length; ++i) {
				var queryPart = queryParts[i];
				var textPart = textParts[i + offset];
				var index = textPart.indexOf(queryPart);
				if (index != 0) {
					continue outer;
				}
				scoreSum += textPart.length - queryPart.length;
			}
			return scoreSum;
		}
	}
}

function searchMatch(text, queryParts) {
	text = text.toLowerCase();
	var textParts = text.split(".");
	var scoreSum = 0;
	for (var i = 0; i < queryParts.length; ++i) {
		var score = match(textParts, queryParts[i]);
		if (score == -1) {
			return -1;
		}
		scoreSum += score + text.length;
	}
	return scoreSum;
}

function errorSearch() {
	var errorURL = "";
	if (!!window.location.pathname) {
		errorURL = window.location.pathname;
	} else if (!!window.location.href) {
		errorURL = window.location.href;
	}
	if (!!errorURL) {
		var searchTerm = errorURL.split("/").pop();
		if (searchTerm.indexOf(".html") > -1) { searchTerm = searchTerm.split(".html").join(""); }
		if (!!searchTerm) {
			// update filter with search term
			$("#search").val(searchTerm);
			searchQuery(searchTerm);
		}
	}
}