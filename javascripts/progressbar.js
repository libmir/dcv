
function progressBarFun(XMLHttpRequest)
  {
      //Upload progress
      XMLHttpRequest.upload.addEventListener("progress", function(evt){
          if (evt.lengthComputable) {  
              var percentComplete = evt.loaded / evt.total;
              //Do something with upload progress
              alert(percentComplete);
          }
      }, false); 
      //Download progress
      XMLHttpRequest.addEventListener("progress", function(evt){
          if (evt.lengthComputable) {
              var percentComplete = evt.loaded / evt.total;
              //Do something with download progress
              alert(percentComplete);
          }
      }, false); 
}

function downloadProgressBarFun(XMLHttpRequest)
  {
      //Download progress
      XMLHttpRequest.addEventListener("progress", function(evt){
          if (evt.lengthComputable) {  
              var percentComplete = evt.loaded / evt.total;
              //Do something with download progress
              alert(percentComplete);
          }
      }, false); 
}

function uploadProgressBarFun(XMLHttpRequest)
  {
      //Upload progress
      XMLHttpRequest.upload.addEventListener("progress", function(evt){
          if (evt.lengthComputable) {  
              var percentComplete = evt.loaded / evt.total;
              //Do something with upload progress
              alert(percentComplete);
          }
      }, false); 
}

function resetProgressBar()
{
    $('.progress').css({
        width: "0px"
    });
    $('.progress').removeClass('hide');
}

function updateProgressBar(evt)
{
    if (evt.lengthComputable) {
        var percentComplete = evt.loaded / evt.total;
        $('.progress').css({
            width: percentComplete * 100 + '%'
        });
        if (percentComplete === 1) {
            $('.progress').addClass('hide');
        }
    }
}

function progressFn() 
{
}
