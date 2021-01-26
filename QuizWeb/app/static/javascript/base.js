 // Highlight current page on menu.
 $(document).ready(function(){
	var csstheme = sessionStorage.getItem("csstheme"); 
	var currentpagecolor = getComputedStyle(document.body).getPropertyValue('--horizontalmenucurrentpage');
		 
	$('.mainmenulink').each(function(i, obj) 
	{
		var currentpage = sessionStorage.getItem("mainmenupage") + " "; 
		if (currentpage !== null && currentpage == $(this).text() )
		{
			$(this).css('background-color', currentpagecolor);
		}	 
	});
	
    var oldlink = document.getElementsByTagName("link").item(2);
	
	if(csstheme !== null)
	{
		oldlink.href = csstheme;
	}		
 });
 
 function SetCurrentPage(name) {
	sessionStorage.setItem('mainmenupage', name);	 
 }
 
 function NotifyUser(message) {
	 alert(message);
 }
 
 function ConfirmUser(message) {
	 confirm(message);
 } 
