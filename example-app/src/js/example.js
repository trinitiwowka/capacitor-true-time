import { RawNtp } from '@trinitiwowka/capacitor-true-time';

const result = document.querySelector('#result');
document.querySelector('#requestNtp').addEventListener('click', async () => {
  try {
    const host = document.querySelector('#ntpHost').value;
    result.textContent = JSON.stringify(await RawNtp.request({ host, timeout: 3000 }), null, 2);
  } catch (error) {
    result.textContent = String(error);
  }
});
