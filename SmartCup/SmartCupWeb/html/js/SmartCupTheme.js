function scaleFontSize(fontSize) {
    return fontSize * 1.5;
}
function parseRGBA(rgbaStr) {
    return rgbaStr.replace(/[^\d,.]/g, '').split(',');
}
function constructRGBA(rgbaArr) {
    return 'rgba(' + rgbaArr[0] + ',' + rgbaArr[1] + ',' + rgbaArr[2] + ',' + rgbaArr[3] + ')'; 
}

function parseFontCss(fontObj) {
    return 'color:' + fontObj.color + ';' +
        'font-size:' + fontObj.fontSize + 'px;' +
        'font-weight:' + fontObj.fontWeight.replace('FontWeight.w', '') + ';';
}
function getLightThemeData() {
    return {canvasColor: "rgba(236,239,241,1.00)",backgroundColor: "rgba(223,229,232,1.00)",primaryColor: "rgba(38,50,56,1.00)",dividerColor: "rgba(207,216,220,1.00)",headline4: {color: "rgba(55,71,79,1.00)",fontSize:12.0,fontWeight:"FontWeight.w800"},headline5: {color: "rgba(55,71,79,1.00)",fontSize:16.0,fontWeight:"FontWeight.w800"},headline6: {color: "rgba(55,71,79,1.00)",fontSize:24.0,fontWeight:"FontWeight.w800"},button: {color: "rgba(207,216,220,1.00)",fontSize:16.0,fontWeight:"FontWeight.w800"},subtitle1: {color: "rgba(55,71,79,1.00)",fontSize:16.0,fontWeight:"FontWeight.w600"},caption: {color: "rgba(69,90,100,1.00)",fontSize:12.0,fontWeight:"FontWeight.w400"},bodyText1: {color: "rgba(55,71,79,1.00)",fontSize:13.0,fontWeight:"FontWeight.w700"},bodyText2: {color: "rgba(55,71,79,1.00)",fontSize:13.0,fontWeight:"FontWeight.w600"},labelStyle: {color: "rgba(84,110,122,1.00)",fontSize:15.0,fontWeight:"FontWeight.w800"}};
}
function getDarkThemeData() {
    return {canvasColor: "rgba(11,15,16,1.00)",backgroundColor: "rgba(19,25,28,1.00)",primaryColor: "rgba(207,216,220,1.00)",dividerColor: "rgba(26,35,39,1.00)",headline4: {color: "rgba(176,190,197,1.00)",fontSize:12.0,fontWeight:"FontWeight.w800"},headline5: {color: "rgba(176,190,197,1.00)",fontSize:16.0,fontWeight:"FontWeight.w800"},headline6: {color: "rgba(176,190,197,1.00)",fontSize:24.0,fontWeight:"FontWeight.w800"},button: {color: "rgba(38,50,56,1.00)",fontSize:16.0,fontWeight:"FontWeight.w800"},subtitle1: {color: "rgba(176,190,197,1.00)",fontSize:16.0,fontWeight:"FontWeight.w600"},caption: {color: "rgba(144,164,174,1.00)",fontSize:12.0,fontWeight:"FontWeight.w400"},bodyText1: {color: "rgba(176,190,197,1.00)",fontSize:13.0,fontWeight:"FontWeight.w700"},bodyText2: {color: "rgba(176,190,197,1.00)",fontSize:13.0,fontWeight:"FontWeight.w600"},labelStyle: {color: "rgba(120,144,156,1.00)",fontSize:15.0,fontWeight:"FontWeight.w800"}};
}

var getThemeData = function () {
    return null;
}

var getSafeArea = function () {
    return null;
}

var _SmartCupThemeScrollInitialised = false;

function setTheme(themeData, safeArea) {
    if (!(safeArea instanceof Object)) {
        safeArea = {};
    }
    safeArea.top = parseInt(safeArea.top);
    safeArea.left = parseInt(safeArea.left);
    safeArea.right = parseInt(safeArea.right);
    safeArea.bottom = parseInt(safeArea.bottom);
    safeArea.extraTop = parseInt(safeArea.extraTop);

    if (isNaN(safeArea.top)) {safeArea.top = 0;}
    if (isNaN(safeArea.left)) {safeArea.left = 0;}
    if (isNaN(safeArea.right)) {safeArea.right = 0;}
    if (isNaN(safeArea.bottom)) {safeArea.bottom = 0;}
    if (isNaN(safeArea.extraTop)) {safeArea.extraTop = 0;}

    var css = '';

    css += 'body{background-color: ' + themeData.canvasColor + ';}';

    css += 'input:-webkit-autofill {' +
        '-webkit-box-shadow: 0 0 0px 1000px ' + themeData.backgroundColor + ' inset;' +
    '}';

    css += '.unsafeLeftRight{' +
        'margin-left:' + (-safeArea.left) + 'px;' + 
        'margin-right:' + (-safeArea.right) + 'px;' + 
    '}';
    css += '.unsafeLeftRight .mainFrame{' +
        'padding-left:' + safeArea.left + 'px;' + 
        'padding-right:' + safeArea.right + 'px;' + 
    '}';

    css += '.primaryColorText{' +
        'color:' + themeData.primaryColor + ';' +
    '}';
    css += '.primaryColorBg{' +
        'background-color:' + themeData.primaryColor + ';' +
    '}';
    css += '.labelStyle{' +
        parseFontCss(themeData.labelStyle) +
    '}';

    css += '.button{' +
        parseFontCss(themeData.button) +
    '}';

    css += '.backgroundColorBg{' +
        'background-color:' + themeData.backgroundColor + ';' +
    '}';

    css += '.main{background-color: ' + themeData.canvasColor + ';}';
    css += '.main{' + 
        'padding-left:' + safeArea.left + 'px;' + 
        'padding-right:' + safeArea.right + 'px;' + 
        'padding-top:' + (safeArea.top + safeArea.extraTop + 64) + 'px;' + 
        'padding-bottom:' + safeArea.bottom + 'px;' + 
    '}';

    
    var h6BgColor = parseRGBA(themeData.canvasColor);
    h6BgColor[3] = 240/255;
    h6BgColor = constructRGBA(h6BgColor);
    themeData.headline6.fontSize *= 1.45;
    css += '.mainTitleContainer{' +
        'padding-left:' + safeArea.left + 'px;' + 
        'padding-right:' + safeArea.right + 'px;' + 
        'padding-top:' + (safeArea.top + safeArea.extraTop) + 'px;' +
        'background-color:' + h6BgColor + ';' +
    '}';
    css += 'h6{' +
        parseFontCss(themeData.headline6) +
    '}';

    var dividerBgColor = parseRGBA(themeData.dividerColor);
    dividerBgColor[3] = 240/255;
    dividerBgColor = constructRGBA(dividerBgColor);
    css += '.sectionTitle{' +
        'top:' + (36 + safeArea.top) + 'px;' + 
        'background-color:' + themeData.canvasColor + ';' +
    '}';
    css += '.sectionTitle.sticky{' +
        'background-color:' + dividerBgColor + ';' +
    '}';
    css += 'h5{' +
        parseFontCss(themeData.headline5) +
    '}';

    var chartAxisColor = parseRGBA(themeData.backgroundColor);
    chartAxisColor[3] = 192/255;
    chartAxisColor = constructRGBA(chartAxisColor);
    var chartAxisFont = Object.assign({}, themeData.bodyText2);
    chartAxisFont.fontSize -= 2;
    chartAxisFont.fontWeight = "FontWeight.w500";
    css += '.chartAxis{' +
        parseFontCss(chartAxisFont) +
        'fill:' + chartAxisColor + ';' +
    '}';
    css += '.sectionCard{' +
        'background-color:' + themeData.backgroundColor + ';' +
    '}';
    css += '.sectionCardTitle{' +
        parseFontCss(themeData.bodyText1) +
        'line-height:' + (themeData.bodyText1.fontSize * 2) + 'px;' +
    '}';

    $('#themeStyle').remove();
    $('<style id="themeStyle" type="text/css">' + css + '</style>').appendTo('head');

    if (!_SmartCupThemeScrollInitialised) {
        $(window).on('scroll', function () {
            var scrollTop = $(this).scrollTop();
            var h6Height = 64;
            var fixedTop = -safeArea.extraTop;

            if (scrollTop < safeArea.extraTop) {
                fixedTop = -scrollTop;
            } else {
                var scrollTopOffset = scrollTop - safeArea.extraTop;
        
                if (scrollTopOffset > 0 && scrollTopOffset <= (64 - 36)) {
                    h6Height = 64 - scrollTopOffset;
                } else if (scrollTopOffset <= 0) {
                    h6Height = 64;
                } else {
                    h6Height = 36;
                }
            }

            $('.mainTitleContainer').css('top', fixedTop + 'px');
            $('.mainTitleContainer').css('height', h6Height + 'px');
            $('.mainTitleContainer').css('line-height', (1.4186 * h6Height - 21.429) + 'px');
            $('h6').css('font-size', getThemeData().headline6.fontSize * (0.0125 * h6Height + 0.2) + 'px');
        
            $('.sectionTitle').each(function (idx, elem) {
                var jElem = $(elem);
        
                var jElemTop = Math.round(jElem.offset().top - scrollTop);
                var stickyTop = (36 + getSafeArea().top);
        
                if (
                    (jElemTop > (stickyTop - 40)) && 
                    (jElemTop <= stickyTop)
                ) {
                    jElem.addClass('sticky');
                } else {
                    jElem.removeClass('sticky');
                }
            })
        });

        _SmartCupThemeScrollInitialised = true;
    }


    getThemeData = function () {
        return themeData;
    }

    getSafeArea = function () {
        return safeArea;
    }

    setTimeout(function () {
        $('body').addClass('show');
    }, 500);
}