import React from 'react'
import Navbar from '../components/Navbar'
import Uploader from '../components/Uploader';
import { useLocation } from 'react-router-dom';


export default function Upload() {

  const location = useLocation();

  return (
    location.state
    ?
    <div>
      <Navbar/>
      <Uploader numero={location.state.numero}/>
    </div>
    :
    <div className="connect-pls">
      Connectez-vous pour accès à cette page.
      <a href="/" className="connect-pls-link">Retourner</a>
    </div>
  )
}
