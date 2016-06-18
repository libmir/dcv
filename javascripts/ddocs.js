
var docs = [
    "dcv_core_algorithm.html", 
    "dcv_core_image.html", 
    "dcv_core_memory.html", 
    "dcv_core_utils.html", 
    "dcv_features_corner_fast_package.html", 
    "dcv_features_corner_harris.html", 
    "dcv_features_corner_package.html", 
    "dcv_features_detector_package.html", 
    "dcv_features_utils.html", 
    "dcv_imgproc_color.html", 
    "dcv_imgproc_convolution.html", 
    "dcv_imgproc_filter.html", 
    "dcv_imgproc_imgmanip.html", 
    "dcv_imgproc_interpolate.html", 
    "dcv_imgproc_threshold.html", 
    "dcv_io_image.html", 
    "dcv_io_package.html", 
    "dcv_io_video_common.html", 
    "dcv_io_video_input.html", 
    "dcv_io_video_output.html", 
    "dcv_plot_draw.html", 
    "dcv_plot_opticalflow.html", 
    "dcv_tracking_opticalflow_hornschunck.html", 
    "dcv_tracking_opticalflow_lucaskanade.html", 
    "dcv_tracking_opticalflow_pyramidflow.html", 
    "dcv_tracking_opticalflow_package.html", 
    "dcv_tracking_opticalflow_base.html", 
];


var examples = [
    "example_filter.html",
    "example_features.html",
    "example_video.html",
    "example_imgmanip.html",
    "example_tracking_hornschunck.html",
    "example_tracking_lucaskanade.html"
];

var DESKTOP_UI = 0;
var PHONE_UI = 1;
var DESKTOP_MIN_WIDTH = 1200;
//var TREE_SYMB_UP = '▲';
//var TREE_SYMB_DOWN = '▼';
var TREE_SYMB_UP = '◎';
var TREE_SYMB_DOWN = '◉';
var CONTENT_SYMB_UP = TREE_SYMB_UP + ' Content';
var CONTENT_SYMB_DOWN =  TREE_SYMB_DOWN + ' Content';

var PROJECT_BOX_WIDTH = "88%"
var PROJECT_BOX_WIDTH_PHONE = "60%";
var PROJECT_BOX_WIDTH_SHRUNK = "65%";

var animationSpeed = 200;
var currentUI = DESKTOP_UI; 
var currentLocation = ""

function replaceAll(str, find, replace) {
    return str.replace(new RegExp(find, 'g'), replace);
}

function hideContent() {
    if (currentUI == DESKTOP_UI) {
        $("#projectbox").animate(
                {width: PROJECT_BOX_WIDTH}, 
                {duration: animationSpeed, queue:false}
                );
    }
    $("#sourcetreebox").hide(animationSpeed);
}

function showContent() {
    if (currentUI == DESKTOP_UI) {
        $("#projectbox").animate(
                {width: PROJECT_BOX_WIDTH_SHRUNK}, 
                {duration: animationSpeed, queue:false}
                );
    }
    $("#sourcetreebox").show(animationSpeed);
    $("#content").text(CONTENT_SYMB_DOWN);
}

function toggleContent() {
    $("#sourcetree").children().toggle(animationSpeed);
    if ($("#content").text() == CONTENT_SYMB_UP) {
        $("#content").text(CONTENT_SYMB_DOWN);
    } else {
        $("#content").text(CONTENT_SYMB_UP);
    }
}

function setupHome() {
    $("#projectbox").animate({width: PROJECT_BOX_WIDTH}, {duration:animationSpeed, queue:false});
    $("#sourcetreebox").hide(animationSpeed, function() {
        window.location.href = "index.html";
    });
}

function loadHTML(path) {
    if (path == "" || path == undefined) 
        return;
    var html = "";
    $.ajax({
        url : path,
        dataType : 'text',
        success: function(result) {
            document.getElementById("pagemain").innerHTML = result;
        }
    });
}

function expandTreeItem(id) {

}

function collapseTreeItem(id) {

}

function isTreeItemCollapsed(id) {

}

function toggleTreeItem(id) {
    if (isTreeItemCollapsed(id))
        expandTreeItem(id);
    else
        collapseTreeItem(id);
}

function setupContent(content) {

    var sourcetree = document.getElementById("sourcetree");
    sourcetree.innerHTML = '';

    if (content.length == 0) {
        hideContent();
        return;
    } 

    content.forEach(function(item, index) {
        tokens = item.replace(".html", "").split("_");

        var ul = null;
        var parentUl = document.getElementById("sourcetree");

        var uniquePath = "";

        for (j = 0; j < tokens.length - 1; ++j) {

            if (j > 0) {
                uniquePath += "_";
            }

            uniquePath += tokens[j];

            ul = document.getElementById(uniquePath);

            if (ul == null) {
                var li= document.createElement("li");

                li.innerHTML = '<a style="outline:none" href="javascript:;">' + TREE_SYMB_DOWN + " " + tokens[j] + '</a>';
                li.id = uniquePath + "_root";
                $(li).css("list-style-type", "none");
                $(li).css("cursor", "pointer");

                ul = document.createElement("ul");
                ul.id = uniquePath;

                parentUl.appendChild(li);
                parentUl.appendChild(ul);

                // setup onclick toggle animation
                li.onclick = function(uniquePath) { return function() {
                    var text = $(this).text();
                    if (text.indexOf(TREE_SYMB_DOWN) != -1) {
                        // it is expanded
                        $(this).text(text.replace(TREE_SYMB_DOWN, TREE_SYMB_UP));
                    } else {
                        $(this).text(text.replace(TREE_SYMB_UP, TREE_SYMB_DOWN));
                    }
                    var ul = document.getElementById(uniquePath);
                    $(ul).children().toggle(animationSpeed);
                }; }(uniquePath);
            }
            parentUl = ul;
        }

        var li = document.createElement("li");
        li.id = item;

        var lis = "<a href=\"javascript:;\">";
        lis += tokens[tokens.length-1];
        lis += "</a>\n";

        li.innerHTML = lis;

        var htmlLoadFunc = function() {
            setLocationQueryString(item);
        };

        li.onclick = htmlLoadFunc;
        $(li).css("list-style-type", "circle");

        parentUl.appendChild(li);
    });

    showContent();
}

/*
function setupContent(content) {

    var sourcetree = document.getElementById("sourcetree");
    sourcetree.innerHTML = '';

    if (content.length == 0) {
        hideContent();
        return;
    } 

    content.forEach(function(item, index) {
        var lis = "";
        var itemtokens = item.split("/");
        var itempretty = itemtokens[itemtokens.length-1].replace(".html", "");
        itempretty = replaceAll(itempretty, "_", ".");
        itempretty = replaceAll(itempretty, ".package", "");
        lis += "<a href=\"javascript:;\">";
        lis += itempretty;
        lis += "</a>\n";


        var li = document.createElement("li");
        li.innerHTML = lis;
        var htmlLoadFunc = function() {
            setLocationQueryString(item);
        };
        li.onclick = htmlLoadFunc;
        sourcetree.appendChild(li);
    });
    showContent();
}
*/

function setupDocumentation() {
    setupContent(docs);
    if (currentUI == PHONE_UI) {
        // collapse sub-packages of dcv
        document.getElementById("dcv_core_root").click();
        document.getElementById("dcv_features_root").click();
        document.getElementById("dcv_imgproc_root").click();
        document.getElementById("dcv_io_root").click();
        document.getElementById("dcv_plot_root").click();
        document.getElementById("dcv_tracking_root").click();
    }
}

function setupExamples() {
    setupContent(examples);
}

function setupPhoneUI() {

    animationSpeed = 0;

    document.getElementById('sourcetreeboxphone').appendChild(document.getElementById('sourcetreebox'));

    $("#sourcetree").children('li').slideUp(animationSpeed);
    $("#menu").css("margin-bottom", "15px");

    $(".roundedbox").css("background", "none");
    $(".roundedbox").css("border", "0px");
    $(".roundedbox").css("padding-top", "0px");
    $(".roundedbox").css("padding-left", "0px");
    $(".roundedbox").css("margin-top", "0px");
    $(".roundedbox").css("margin-left", "0px");

    $("#sourcetreebox").css('min-height', '0');
    $("#sourcetreebox").css('width', '95%');
    $("#sourcetreebox").css('padding-left', '10px');

    $("#sourcetreebox").css('border', '1px solid rgb(230, 230, 230)');
    $("#sourcetreebox").css('border-radius', '8px');

    $('#return-to-top').hide();
    hideContent();
}

function setupDesktopUI() {

    animationSpeed = 200;

    document.getElementById('sourcetreeboxdesktop').appendChild(document.getElementById('sourcetreebox'));

    $(".roundedbox").css("border-radius", "16px");
    $(".roundedbox").css("background", "#f4f4f4");
    $(".roundedbox").css("border", "1px solid #e0e0e0");
    $(".roundedbox").css("padding", "15px");
    $(".roundedbox").css("margin", "10px");

    $("#sourcetreebox").css("width", "270px");
    $("#sourcetreebox").css('min-height', '500px');
    $("#projectbox").css("width", PROJECT_BOX_WIDTH);
    hideContent();
}

function evalSize() {
    screenWidth = window.innerWidth;
    if (screenWidth < DESKTOP_MIN_WIDTH && currentUI != PHONE_UI) {
        setupPhoneUI();
        currentUI = PHONE_UI;
    } else if (screenWidth >= DESKTOP_MIN_WIDTH && currentUI != DESKTOP_UI) {
        setupDesktopUI();
        currentUI = DESKTOP_UI;
    }
}

function reloadQueryLocation() {
    var loc = getLocationFromQueryString();
    if (currentLocation == loc)
        return;

    currentLocation = loc;
    loadHTML(loc);
}

function loadQueryLocation() {
    loadHTML(getLocationFromQueryString());
}

function setLocationQueryString(location) {

    currentLocation = location;
    newLocation = "?loc=" + location;

    var newurl = window.location.protocol + "//" + window.location.host + window.location.pathname + '?loc=' + location;
    window.history.pushState({path:newurl},'',newurl);

    loadQueryLocation();
}

function getLocationFromQueryString() {
    tokens = window.location.href.split("?");
    str = "";
    if (tokens.length >=2 )
        str = tokens[1];
    else
        return;

    return str.split("=")[1];
}

$(document).ready(function(e) {

    // setup content toggle
    $("#content").click(toggleContent);

    // always hide the source tree box on startup
    $("#sourcetreebox").hide();

    document.getElementById("homelink").onclick = setupHome;
    document.getElementById("doclink").onclick = setupDocumentation;
    document.getElementById("exampleslink").onclick = setupExamples;
    window.onresize = evalSize;

    // setup return-to-top behaviour
    $(window).scroll(function() {
        if ($(this).scrollTop() >= 50) {
            $('#return-to-top').fadeIn(animationSpeed);
        } else {
            $('#return-to-top').fadeOut(animationSpeed);
        }
    });

    $('#return-to-top').click(function() {
        $('body,html').animate({
            scrollTop : 0
        }, animationSpeed*2);
    });

    evalSize();

    $(window).on('popstate', function(event) {
        location.reload();
    });

    reloadQueryLocation();
});

