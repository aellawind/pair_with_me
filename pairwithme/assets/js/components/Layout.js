'use strict';

import React from 'react';

/* Layout page that is used in every section of application
 * Components defined in the nested routes will be rendered inside
 * this Layout component in place of the this.props.children property
 */
export default class Layout extends React.Component {
    render() {
        return (
            <div className="app-container">
                <header>
                </header>
                <div> HI KATIA</div>
                <div className="app-content">{this.props.children}</div>
                <footer>
                    <p id="footer">
                        FOOOOOTER
                    </p>
                </footer>
            </div>
        );
  }
}