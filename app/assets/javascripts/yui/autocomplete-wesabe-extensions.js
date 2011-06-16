YAHOO.widget.AutoComplete.prototype.doubleQuoteOverrides         = null;
YAHOO.widget.AutoComplete.prototype.doubleQuoteResultsWithSpaces = null;


YAHOO.widget.AutoComplete.prototype.formatResult = function(oResultItem, sQuery) {
  var sResult = oResultItem[0];
  if(sResult) {
      // I'm so pretty, oh so pretty -- Wrap the substring
      // match in a span so we can apply fancy styles, bold!
      var idx  = sResult.toLowerCase().indexOf(sQuery.toLowerCase());
      var head = sResult.substr(0,idx);
      var body = sResult.substr(idx,idx+sQuery.length)
      var tail = sResult.substr(idx+sQuery.length,sResult.length);
      return head + '<span>' + body + '</span>' + tail;
  }
  else {
      return "";
  }
}

YAHOO.widget.AutoComplete.prototype._sendQuery = function(sQuery) {
    // Widget has been effectively turned off
    if(this.minQueryLength < 0) {
        this._toggleContainer(false);
        return;
    }
    // Delimiter has been enabled
    var aDelimChar = (this.delimChar) ? this.delimChar : null;
    if(aDelimChar) {
        // Allow double-quotes to override all other delimiters,
        // this is useful if you want to allow spaces both as a delimiter and as
        // a compound charcter. E.G. 'power water "natual gas"' ...
        if (this.doubleQuoteOverrides &&
            /\"/g.test(sQuery) && sQuery.match(/\"/g).length % 2 != 0) {
          aDelimChar = [ '"' ];
        }

        // Loop through all possible delimiters and find the rightmost one in the query
        // A " " may be a false positive if they are defined as delimiters AND
        // are used to separate delimited queries
        var nDelimIndex = -1;
        for(var i = aDelimChar.length-1; i >= 0; i--) {
            var nNewIndex = sQuery.lastIndexOf(aDelimChar[i]);
            if(nNewIndex > nDelimIndex) {
                nDelimIndex = nNewIndex;
            }
        }
        // If we think the last delimiter is a space (" "), make sure it is NOT
        // a false positive by also checking the char directly before it
        if(aDelimChar[i] == " ") {
            for (var j = aDelimChar.length-1; j >= 0; j--) {
                if(sQuery[nDelimIndex - 1] == aDelimChar[j]) {
                    nDelimIndex--;
                    break;
                }
            }
        }
        // A delimiter has been found in the query so extract the latest query from past selections
        if(nDelimIndex > -1) {
            var nQueryStart = nDelimIndex + 1;
            // Trim any white space from the beginning...
            while(sQuery.charAt(nQueryStart) == " ") {
                nQueryStart += 1;
            }
            // ...and save the rest of the string for later
            this._sPastSelections = sQuery.substring(0,nQueryStart);
            // Here is the query itself
            sQuery = sQuery.substr(nQueryStart);
        }
        // No delimiter found in the query, so there are no selections from past queries
        else {
            this._sPastSelections = "";
        }
    }

    // Don't search queries that are too short
    if((sQuery && (sQuery.length < this.minQueryLength)) || (!sQuery && this.minQueryLength > 0)) {
        if(this._nDelayID != -1) {
            clearTimeout(this._nDelayID);
        }
        this._toggleContainer(false);
        return;
    }

    sQuery = encodeURIComponent(sQuery);
    this._nDelayID = -1;    // Reset timeout ID because request is being made

    // Subset matching
    if(this.dataSource.queryMatchSubset || this.queryMatchSubset) { // backward compat
        var oResponse = this.getSubsetMatches(sQuery);
        if(oResponse) {
            this.handleResponse(sQuery, oResponse, {query: sQuery});
            return;
        }
    }

    if(this.responseStripAfter) {
        this.dataSource.doBeforeParseData = this.preparseRawResponse;
    }
    if(this.applyLocalFilter) {
        this.dataSource.doBeforeCallback = this.filterResults;
    }

    var sRequest = this.generateRequest(sQuery);
    this.dataRequestEvent.fire(this, sQuery, sRequest);

    this.dataSource.sendRequest(sRequest, {
            success : this.handleResponse,
            failure : this.handleResponse,
            scope   : this,
            argument: {
                query: sQuery
            }
    });
};

YAHOO.widget.AutoComplete.prototype._updateValue = function(elListItem) {
    if(!this.suppressInputUpdate) {
        var elTextbox = this._elTextbox;
        var sDelimChar = (this.delimChar) ? (this.delimChar[0] || this.delimChar) : null;
        var sResultMatch = elListItem._sResultMatch;

        // andre: the click was not on an autocomplete option, probably the footer
        if (!sResultMatch) return;

        // if we're quoting results with spaces AND the result has a
        // space then, you guessed it, wrap the result string in double quotes!
        if (this.doubleQuoteResultsWithSpaces && sDelimChar == " " && sResultMatch.match(/\s/)) {
          sResultMatch = ['"', sResultMatch, '"'].join('');
        }

        // Calculate the new value
        var sNewValue = "";
        if(sDelimChar) {
            // Preserve selections from past queries
            sNewValue = this._sPastSelections;
            // if there are an odd number of double quotes, remove
            // the last double quote and any spaces. This is needed to ensure we do
            // not end up with extra leading quotes.
            if (this.doubleQuoteResultsWithSpaces &&
                /\"/.test(sNewValue) && sNewValue.match(/\"/g).length % 2 != 0) {
              sNewValue = sNewValue.replace(/\"\s*$/,'');
            }
            // Add new selection plus delimiter
            sNewValue += sResultMatch + sDelimChar;
            if(sDelimChar != " ") {
                sNewValue += " ";
            }
        }
        else {
            sNewValue = sResultMatch;
        }

        // Update input field
        elTextbox.value = sNewValue;

        // Scroll to bottom of textarea if necessary
        if(elTextbox.type == "textarea") {
            elTextbox.scrollTop = elTextbox.scrollHeight;
        }

        // Move cursor to end
        var end = elTextbox.value.length;
        this._selectText(elTextbox,end,end);

        this._elCurListItem = elListItem;
    }
};
