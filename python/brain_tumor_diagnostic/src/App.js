import "./App.css"
import Login from "./pages/Login";
import {Routes, Route } from "react-router-dom";
import Upload from "./pages/Upload";
import Results from "./pages/Results";

function App() {
  return (
    <div className="App">
      <Routes>
        <Route path="/" Component={Login}/>
        <Route path="/upload" Component={Upload}/>
        <Route path={`:medecin/:patient`} Component={Results}/>
      </Routes>
    </div>
  );
}

export default App;
