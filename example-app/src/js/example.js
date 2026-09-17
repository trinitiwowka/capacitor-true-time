import { TrueTime } from '@trinitiwowka/capacitor-true-time';

window.testEcho = () => {
    const inputValue = document.getElementById("echoInput").value;
    TrueTime.echo({ value: inputValue })
}
