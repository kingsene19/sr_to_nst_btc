import React from 'react'
import bgimg from "../images/landing.jpg";
import { useForm } from "react-hook-form";
import { FaBrain } from 'react-icons/fa';
import { useNavigate } from 'react-router-dom';

export default function Login() {

    const { register, handleSubmit, formState: {errors}} = useForm();
    const navigate  = useNavigate();

    const onSubmit =  (data) => {
        setTimeout(() => {
            navigate("/upload", {state: {"numero": data.numero}});
        })
    };

    return (
        <div className="register primary">
            <div className="col-1">
                <span><FaBrain className="nav-icon"/></span><br/>
                <h2>Brain Tumor Diagnostic Helper</h2>
                <span class="reg-span">Vous pouvez charger vos xray pour en améliorer la résolution, avoir une aide à la prise de décision sur eux ainsi que masquer les informations avant envoie des résultats au patient</span>
                <form id="form" className='flex flex-col' onSubmit={handleSubmit(onSubmit)}>
                    <input type="text" {...register("name",{required: true})} placeholder="Nom complet"/>
                    {errors.name?.type==='required' && "Le nom est requis"}
                    <input type="text" {...register("numero",{required: true})} placeholder="Numéro"/>
                    {errors.numero?.type==='required' && "Le numéro est requis"}
                    <input type="password" {...register("mdp",{required: true})} placeholder="Mot de passe"/>
                    {errors.name?.type==='required' && "Le mot de passe est requis"}

                    <button className="btn">Connexion</button>
                </form>
            </div>
            <div className="col-2">
                <img src={bgimg} alt=""/>
            </div>
        </div>
    );
}
