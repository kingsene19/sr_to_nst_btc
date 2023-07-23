import React from "react";
import {FaBrain} from "react-icons/fa"
import { useNavigate } from "react-router-dom";


export default function Navbar () {

    const navigate =  useNavigate();
  
    const handleDisconnect = () => {
      navigate("/", {replace: true})
    }

    return (
        <div className="nav primary">
            <div className="nav-left">
                <FaBrain className="nav-icon"/>
                <span className="nav-span">Brain Tumor Diagnostic Helper</span>
            </div>
            <div className="nav-right">
                <button className="nav-btn" onClick={handleDisconnect}>Déconnexion</button>
            </div>
        </div>
    );
}