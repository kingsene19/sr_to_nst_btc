import React, { useState } from 'react';
import axios from 'axios';
import { useLocation } from 'react-router-dom';
import Navbar from '../components/Navbar';

export default function Results() {

    const location = useLocation();

    const numero = location.state.numero;
    const patient = location.state.patient;
    const imagebase64 = location.state.imagebase64;
    const [hidden, setHidden] = useState(true);

    const handleOnClick= async () => {
        const url = "http://127.0.0.1:5000/getInfos";
        const data = {
            'medecin': numero,
            "patient": patient,
        };
        const result = await axios.get(url, {params: data});

        console.log(result.data);

        document.getElementById("nom").value =  result.data.nom;
        document.getElementById("prenom").value = result.data.prenom;
        document.getElementById("diagnostic").value = result.data.diagnostic;
        document.getElementById("medecin").value = result.data.medecin;
        setHidden(false);
    };

    return (

        <div>
            <Navbar/>
            <div className="upload-div">
                <h3>Résultats de votre XRAY</h3>
                <form 
                    action="" 
                    className="upload-form"
                > 
                    <img src={`data:image/jpeg;base64,${imagebase64}`} width={250} height={250} alt=""/>
                </form>
                <button className="nav-btn-upload" onClick={handleOnClick}>Afficher</button>
                <div className='main-container' hidden={hidden}>
                    <div className='modal-container'>
                        <div className='modal-input-label'>
                            <label className='modal--input-text'>Nom</label>
                            <input
                                id="nom"
                                className='modal-input'
                                type="text"
                                disabled={true}
                            />
                        </div>
                        <div className='modal-input-label'>
                            <label className='modal--input-text'>Prenom</label>
                            <input
                                id="prenom"
                                className='modal-input'
                                type="text"
                                disabled={true}
                            />
                        </div>
                        <div className='modal-input-label'>
                            <label className='modal--input-text'>Resultat</label>
                            <input
                                id="diagnostic"
                                className='modal-input'
                                type="text"
                                disabled={true}
                            />
                        </div>
                        <div className='modal-input-label'>
                            <label className='modal--input-text'>Medecin</label>
                            <input
                                id="medecin"
                                className='modal-input'
                                type="text"
                                disabled={true}
                            />
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );

}
