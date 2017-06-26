'use strict';

import React from 'react';
import Square from './Square';

/* Board component where we will render the squares
 */
export default class Board extends React.Component {
    renderSquare(wine) {
        return (
            <div key={wine.id}>
                <Square wine={wine} />
            </div>
        )
    }

    render() {
        const {wines} = this.props

        return (
            <div className="board">
                { wines.map(this.renderSquare) }
            </div>
        );
  }
}