'use strict';

import React from 'react';
// import img from '../../images/wines/syrah.jpg'


/* Square that holds smaller image of food or wine.
 */
export default class Square extends React.Component {
    getImageUrl() {
    	let {wine} = this.props;

        const fileName = wine.name.toLowerCase()
        return `/static/images/wines/${fileName}.jpg`;
    }

    render() {
        return (
            <a href={`/wines/${this.props.wine.id}/`}>
                <div className="squareContainer">
                    <img src={this.getImageUrl()} />
                    <div className="squareSummary">
                        <div className="squareName">
                            {this.props.wine.name}
                        </div>
                    </div>
                </div>
            </a>
        );
  }
}