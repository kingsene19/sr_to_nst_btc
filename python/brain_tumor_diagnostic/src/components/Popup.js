import React from 'react';
import { useState } from 'react';
import axios from 'axios';
import FormData from 'form-data';
import { useNavigate } from 'react-router-dom';

export default function Popup({lowres, numero}) {

    const navigate = useNavigate();

    const [nom, setNom] = useState("");
    const [prenom, setPrenom] = useState("");
    const [patient, setPatient] = useState("");
    const [resultat, setResultat] = useState("");
    const [email, setEmail] = useState("");
    const [slug, setSlug] = useState("");
    const [confidence, setConfidence] = useState("");
    const [requestSent, setRequestSent] = useState(false);
    const [emailSent, setEmailSent] = useState(false);
    const [finalImage, setFinalImage] = useState(null);


    const handleSubmit = async () => {
        const url = "http://127.0.0.1:5000/getRecommendation";

        const form = new FormData();
        form.append("numero", numero);
        form.append("patient", document.getElementById("patient").value);
        const result = await axios.post(url, form);
        document.getElementById("result").value = result.data.prediction;
        document.getElementById("confidence").value = result.data.confidence;
        setRequestSent(true);
    }

    const handleEmail = async () => {
        const url = "http://127.0.0.1:5000/addInfos";

        const form = new FormData();
        form.append("nom", document.getElementById("nom").value);
        form.append("prenom", document.getElementById("prenom").value)
        form.append("medecin", numero);
        form.append("patient", document.getElementById("patient").value);
        form.append("diagnostic", document.getElementById("result").value);
        const result = await axios.post(url, form);
        console.log(result);

        setEmailSent(true);
        setFinalImage(result.data.hidden_base64);
        setSlug(document.getElementById("patient").value);
    };

    const handleOnClick = () => {
        setTimeout(() => {
            navigate(`/${numero}/${slug}`, {state: {"numero": numero, "imagebase64": finalImage, "patient": slug, "lowres": lowres}});
        })
    }

    return (
        <>
        {!emailSent && (
            <div className='main-container'>
                <div className='modal-container'>
                    <div className='modal-input-label'>
                        <label className='modal--input-text'>Nom</label>
                        <input 
                            id="nom"
                            label={nom}
                            className='modal-input'
                            type="text"
                            onChange={(nom) => setNom(nom)}
                        />
                    </div>
                    <div className='modal-input-label'>
                        <label className='modal--input-text'>Prenom</label>
                        <input 
                            id="prenom"
                            label={prenom}
                            className='modal-input'
                            type="text"
                            onChange={(prenom) => setPrenom(prenom)}
                        />
                    </div>
                    <div className='modal-input-label'>
                        <label className='modal--input-text'>Numero Patient</label>
                        <input 
                            id="patient"
                            label={patient}
                            className='modal-input'
                            type="text"
                            onChange={(patient) => setPatient(patient)}
                        />
                    </div>
                    <div className='modal-input-label'>
                        <label className='modal--input-text'>Resultat</label>
                        <input 
                            id='result'
                            label={resultat}
                            className='modal-input'
                            type="text"
                            onChange={(resultat) => setResultat(resultat)}
                        />
                    </div>
                    <div className='modal-input-label'>
                        <label className='modal--input-text'>Niveau de confiance</label>
                        <input 
                            id='confidence'
                            label={confidence}
                            className='modal-input'
                            type="text"
                            disabled={true}
                            onChange={(confiance) => setConfidence(confiance)}
                        />
                    </div>
                    {
                        requestSent?
                        <div className='modal-input-label'>
                            <label className='modal--input-text'>Email</label>
                            <input 
                                id="email"
                                label={email}
                                className='modal-input'
                                type="text"
                                onChange={(email) => setEmail(email)}
                            />
                        </div>
                        :<></>
                    }
                    <div>
                        <button
                            className='modal-footer-button modal-button-send'
                            onClick = {() => {
                                if (requestSent) {
                                    handleEmail();
                                } else {
                                    handleSubmit();
                                }
                            }}
                        >
                            Envoyer
                        </button>
                    </div>
                </div>
            </div>
        )}
        {emailSent && (
            <div className='modal-container-sent'>
                <h3>Les résultats sont disponibles. Pour y accèder cliquez le lien suivant:</h3>
                <a onClick={handleOnClick}>Voir résultats</a>
            </div>
        )}
        </>
    );

}
