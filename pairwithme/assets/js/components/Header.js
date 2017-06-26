'use strict';

import React from 'react';

/* Header bar where we put the search box and also the toggle to show
 * either the wine or food view
 */
export default class Header extends React.Component {
    render() {
        return (
            <div className="header">
                <input type="text" className="searchBox" placeholder="Search"></input>
            </div>
        );
  }
}