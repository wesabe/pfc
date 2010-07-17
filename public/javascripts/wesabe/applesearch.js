if (!applesearch)	var applesearch = {};

applesearch.init = function ()
{
	var srchform = document.getElementById('searchform');

	// Paranoia! Make sure we can get the search form before trying anything
	if(srchform) {

		var srchinput = document.getElementById('query');
		labelText = applesearch.getLabelText();

		// add applesearch css for non-safari, dom-capable browsers
		if ( navigator.userAgent.toLowerCase().indexOf('safari') < 0  && document.getElementById ) {
			this.clearBtn = false;

			// add style sheet if not safari
			$('head').append('<link rel="stylesheet" href="/stylesheets/applesearch.css" type="text/css" />');

			//------------------

			// create and attach the span
			var r_crnr = document.createElement('span');
			r_crnr.className = 'sbox_r'; // IE win doesn't like setAttribute in this case
			r_crnr.setAttribute('id','srch_clear');

			var fieldsets = srchform.getElementsByTagName('fieldset');
			if (fieldsets) {
				fieldsets[0].appendChild(r_crnr);
			}

			// Create and attach a clearing div, keeps Opera happy
			var d_clr = document.createElement('div');
			d_clr.setAttribute('class','clear');
			srchform.appendChild(d_clr);

			//------------------

			// set our text colors
			var labels = srchform.getElementsByTagName('label');

			if (labels) {
				if (labels[0].currentStyle) {
					// must be using IE
					labelColor = labels[0].currentStyle.color;
					inputColor = srchinput.currentStyle.color;
				} else if (document.defaultView.getComputedStyle) {
					labelColor = document.defaultView.getComputedStyle(labels[0], null).getPropertyValue('color');
					inputColor = document.defaultView.getComputedStyle(srchinput, null).getPropertyValue('color');
				}
			}

			//------------------

			// Paranoia again! Make sure the search field exist
			if(srchinput) {
				// set the placeholder text based off the label
				srchinput.value = labelText;
				srchinput.style.color = labelColor;

				// add some events to the input field
				srchinput.onkeyup = function () {
						applesearch.onChange('query','srch_clear');
					}
				srchinput.onfocus = function () {
						if (this.value == labelText) {
							this.value = '';
							this.style.color = inputColor;
						}
					}
				srchinput.onblur = function () {
						if (this.value == '') {
							this.value = labelText;
							this.style.color = labelColor;
						}
					}
			}

			// prevent the form being submitted if the input's value is the placeholder (label) text
			srchform.onsubmit = function()
			{
				if(srchinput && srchinput != labelText) {
					return true;
				} else {
					return false;
				}
			}
		} else {
			// Paranoia again! Make sure the search field exist
			if(srchinput) {
				// Using Safari so change some attributes to get the Apple Search field
				srchinput.type = 'search';
				srchinput.setAttribute('placeholder',labelText);
				srchinput.setAttribute('autosave','bsn_srch');
				srchinput.setAttribute('results','5');
			}
		}
	}
}

applesearch.getLabelText = function()
{
	var srchform = document.getElementById('searchform');
	if(srchform) {
		var labels = srchform.getElementsByTagName('label');

		if (labels) {
			var labelFor = labels[0].getAttribute('for');
			var labelText = labels[0].firstChild.nodeValue;
		} else {
			// just in case, set default text
			var labelText = 'Search';
		}
	} else {
		// just in case, set default text
		var labelText = 'Search';
	}
	return labelText;
}

applesearch.setLabelText = function(newLabel) {
  var srchinput = document.getElementById('query');
  labelText = newLabel;
  if ( navigator.userAgent.toLowerCase().indexOf('safari') < 0  && document.getElementById ) {
    srchinput.value = labelText;
  } else {
    srchinput.setAttribute('placeholder',labelText);
  }
}

// called when on user input - toggles clear fld btn
applesearch.onChange = function (fldID, btnID)
{
	// check whether to show delete button
	var fld = document.getElementById( fldID );
	var btn = document.getElementById( btnID );

	if (fld.value.length > 0 && fld.value != labelText && !this.clearBtn) {
		btn.className = 'sbox_r_f2';
		btn.fldID = fldID; // btn remembers it's field
		btn.onclick = this.clearBtnClick;
		this.clearBtn = true;
	}
}

applesearch.onBlur = function(fldID, btnID)
{
  if (fld.value.length == 0 && this.clearBtn) {
		btn.className = 'sbox_r';
		btn.onclick = null;
		this.clearBtn = false;
		// reset the field's placeholder text
		fld.value = labelText;
		fld.style.color = labelColor;
	}
}

applesearch.clearFld = function (fldID,btnID)
{
	var fld = document.getElementById( fldID );
	fld.value = '';
	this.onChange(fldID,btnID);
}

applesearch.clearBtnClick = function ()
{
	applesearch.clearFld(this.fldID, this.id);
}

// Actually run the init function once the page is loaded
$(function(){ applesearch.init(); });
