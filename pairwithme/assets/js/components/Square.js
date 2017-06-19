'use strict';

import React from 'react';
import img from '../../images/wines/syrah.jpg'


/* Square that holds smaller image of food or wine.
 */
export default class Square extends React.Component {
    render() {
        return (
            <div>
            	<img src={img}/>
                <h1>{this.props.wine.name}</h1>
            </div>
        );
  }
}