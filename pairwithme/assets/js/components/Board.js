'use strict';

import React from 'react';
import Square from './Square';

/* Board component where we will render the squares
 */
export default class Board extends React.Component {
    render() {
        return (
            <div className="header">
                <Square />
                <Square />
                <Square />
                <Square />
            </div>
        );
  }
}