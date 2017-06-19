'use strict';

import React from 'react';
import Hero from './Hero';
import Board from './Board';

/* Listing page for either the food or the wine
 */
export default class Listing extends React.Component {
    render() {
        return (
            <div className="listing">
            	<Hero />
            	<Board />
                THIS IS THE LISTING
            </div>
        );
  }
}