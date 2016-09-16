
//var DCV_SERVER_ADDRESS = "http://127.0.0.1:8080";
var DCV_SERVER_ADDRESS = "http://dcv-service.azurewebsites.net"
var ACTIVE_BRANCH = "master";

function loadExample(example)
{
    resetProgressBar();
    example = example.replace("example_", "")
    $.ajax({
        url : DCV_SERVER_ADDRESS + '/examples/' + example,
        dataType : 'text',
        xhr: function () {
            var xhr = new window.XMLHttpRequest();
            xhr.addEventListener("progress", function (evt) {
                if (evt.lengthComputable) {
                    var percentComplete = evt.loaded / evt.total;
                    console.log(percentComplete);
                    $('.progress').css({
                        width: percentComplete * 100 + '%'
                    });
                    if (percentComplete == 1) {
                        $('.progress').addClass('hide');
                    }
                }
            }, false);
            return xhr;
        },
        success :
            function(data)
            {
                var page = document.getElementById("pagemain");
                page.innerHTML = data;
            }
    });
}

function loadContributors(file)
{
    $.ajax({
        url : DCV_SERVER_ADDRESS + '/contributors/' + ACTIVE_BRANCH + "/" + file,
        dataType : 'text',
        success :
            function(data)
            {
                var page = document.getElementById("contributors");
                page.innerHTML = "<div style=\"margin:10px;\"><h3 style=\"margin-bottom:3px;\">Contributors:</h3>" + data + "</div>";
            }
    });
}

function loadProjectContributors()
{
    $.ajax({
        url: DCV_SERVER_ADDRESS + '/contributors',
        dataType : 'text',
        success :
            function(data) 
            {
                var contributorsDiv = document.getElementById("project-contributors");
                contributorsDiv .innerHTML += data;
            }
    });
}

function listExamples(branch, fun)
{
    $.ajax({
        url: DCV_SERVER_ADDRESS + '/listExamples/' + branch,
        dataType : 'text',
        success : fun
    });
}
