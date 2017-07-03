'use strict';

import React from 'react';

/* Header bar where we put the search box and also the toggle to show
 * either the wine or food view
 */
export default class SearchHeader extends React.Component {
    handleKeyPress(submitSearch) {
    	return function(event) {
    		if (event.key === 'Enter') {
    			submitSearch(event.target.value);
    		}
        }
    }

    render() {
    	let {submitSearch} = this.props;

        return (
            <div className="header">
                <input onKeyPress={this.handleKeyPress(submitSearch)} type="text" className="searchBox" placeholder="Search"></input>
            </div>
        );
  }
}