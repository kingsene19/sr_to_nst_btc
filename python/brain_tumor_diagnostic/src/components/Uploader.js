import React, {useState} from 'react';
import { MdCloudUpload, MdDelete } from "react-icons/md"
import { AiFillFileImage } from "react-icons/ai"
import Popup from './Popup';
import axios from 'axios';

export default function Uploader({numero}) {

    const [lowres, setLowRes] = useState(null);
    const [superres, setSuperRes] = useState(null);
    const [filename, setFileName] = useState("Aucun fichier choisi");

    const handleSubmit = async (file) => {
        const url = "http://127.0.0.1:5000/getImages";

        const form = new FormData();
        form.append("file", file, filename);
        form.append("numero", numero);
        form.append("patient", document.getElementById("patient").value);
        const result = await axios.post(url, form);
        setLowRes(result.data.lowres_image);
        setSuperRes(result.data.superres_image);
    }

    return (
        <div className="upload-div">
            <form 
                action="" 
                className="upload-form"
                onClick={() => document.querySelector(".input-field").click()}
            > 
                <input 
                    type="file" 
                    accept="image/*" 
                    className='input-field' 
                    onChange = {({target: {files}}) => {
                        files[0] && setFileName(files[0].name)
                        if (files) {
                            handleSubmit(files[0]);
                        }
                    }}
                    hidden
                />
                <div className='input-images'>
                    {
                        lowres ?
                        <div className='input-images-div'>
                            <span className="input-images-title">Image Initiale</span>
                            <img src={`data:image/jpeg;base64,${lowres}`} width={250} height={250} alt={filename}/>
                        </div>  
                        :
                        <>
                            <MdCloudUpload color="#000" size={120}/>
                            <p>Choisir une image à analyser</p>
                        </>  
                    }
                    {
                        superres ?
                        <div className='input-images-div'>
                            <span className='input-images-title'>Image super résolue</span>
                            <img src={`data:image/jpeg;base64,${superres}`} width={250} height={250} alt={filename}/>
                        </div>
                        :
                        <></>
                    }
                </div>
            </form>

            <div className='upload-row'>
                <AiFillFileImage color="#000000"/>
                <span>
                    {filename}
                    <MdDelete
                        onClick={() => {
                            setFileName("Aucun fichier choisi");
                            setLowRes(null);
                            setSuperRes(null);
                        }}
                    />
                </span>
            </div>

            <Popup lowres={lowres} numero={numero} superres={superres}/>
        </div>
    );
}
