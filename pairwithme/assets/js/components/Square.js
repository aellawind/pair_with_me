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
            <div>
                <img src={this.getImageUrl()} />
                <h1>{this.props.wine.name}</h1>
            </div>
        );
  }
}