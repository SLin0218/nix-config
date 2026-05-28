#!/usr/bin/env python
# -*- coding: utf-8 -*
import base64
import hashlib
import json
import time
from urllib.parse import quote, urlencode

import requests
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from rich import print, console

console = console.Console()

from translate import Translate


class ICibaTranslate(Translate):
    url = "http://dict.iciba.com/dictionary/word/query/web"
    sentence_url = (
        "http://ifanyi.iciba.com/index.php"
        "?c=trans&m=fy&client=6&auth_user=key_web_new_fanyi&sign="
    )

    def source(self):
        return 1

    def signature(self, params):
        code = (
            "/dictionary/word/query/web"
            + params["client"]
            + params["key"]
            + params["timestamp"]
            + params["word"]
            + "7ece94d9f9c202b0d2ec557dg4r9bc"
        )
        md5 = hashlib.md5()
        md5.update(code.encode("utf-8"))
        return md5.hexdigest()

    def encryptor(self, key: str, data: str):
        cipher = AES.new(key.encode("utf-8"), AES.MODE_ECB)
        padded_data = pad(data.encode("utf-8"), AES.block_size)
        encrypted_data = cipher.encrypt(padded_data)
        return base64.b64encode(encrypted_data).decode("utf-8")

    def decryptor(self, key: bytes, content: str):
        content_bytes = base64.b64decode(content)
        cipher = Cipher(algorithms.AES(key), modes.ECB(), backend=default_backend())
        decryptor = cipher.decryptor()
        decrypted_data = decryptor.update(content_bytes) + decryptor.finalize()
        decrypted_data = decrypted_data.decode("utf-8")
        # } 后面有些无关的字符, 截取掉这部分数据
        decrypted_data = decrypted_data[: decrypted_data.rfind("}") + 1]
        return decrypted_data

    def sentence_signature(self, q: str):
        code = "6key_web_new_fanyi6dVjYLFyzfkFkk" + q.strip()
        md5 = hashlib.md5()
        md5.update(code.encode("utf-8"))
        sign = md5.hexdigest()[:16]
        return self.encryptor("L4fBtD5fLC9FQw22", sign)

    def translate_sentence(self, word, zh=False):
        post_data = {"from": "en", "to": "zh", "q": word}
        if zh:
            post_data = {"from": "zh", "to": "en", "q": word}
        r = requests.post(
            self.sentence_url + self.sentence_signature(word), data=post_data
        )
        response = r.json()
        response = self.decryptor(b"aahc3TfyfCEmER33", response["content"])
        return json.loads(response)

    def translate_word(self, word):
        query = {
            "client": "6",
            "key": "1000006",
        }
        query["word"] = quote(word)
        query["timestamp"] = str(int(round(time.time() * 1000)))
        query["signature"] = self.signature(query)
        r = requests.get(self.url + "?" + urlencode(query))
        return r.json()

    def pretty_print(self, rj):
        if "out" in rj:
            print()
            print(f"[red]{rj['out']}[/red]")
            return

        message = rj["message"]
        baes_info = message["baesInfo"]

        if "symbols" in baes_info:
            symbols = baes_info["symbols"][0]
            type_map = {"ph_en": "英", "ph_am": "美", "word_symbol": "中"}
            sysbols_output = ""
            for skey in symbols:
                if skey in type_map:
                    symbols_text = symbols[skey]
                    if symbols_text:
                        sysbols_output = (
                            sysbols_output
                            + f"{type_map[skey]} [[red]{symbols_text}[/]]   "
                        )
            if sysbols_output:
                print(sysbols_output)

            if "ph_en_mp3" in symbols and symbols["ph_en_mp3"]:
                self.mp3_url = symbols["ph_en_mp3"]
            elif "ph_am_mp3" in symbols and symbols["ph_am_mp3"]:
                self.mp3_url = symbols["ph_am_mp3"]
            elif "ph_tts_mp3" in symbols and symbols["ph_tts_mp3"]:
                self.mp3_url = symbols["ph_tts_mp3"]

            self.play_mp3()

            print()

            if "fromSymbolsMean" in baes_info:
                if len(baes_info["fromSymbolsMean"]) > 0:
                    fromSymbolsMean = baes_info["fromSymbolsMean"][0]
                    for word_tmp in fromSymbolsMean["word"][0]["word"]:
                        means = word_tmp["symbols"][0]["parts"][0]["means"]
                        print(f"[blue]{word_tmp['word_name']}：{'；'.join(means)}[/]")
            else:
                for part in symbols["parts"]:
                    print(f"[blue]{part['part']} {'；'.join(part['means'])}[/]")

        if "exchange" in baes_info:
            exchange = baes_info["exchange"]
            print()
            type_map = {
                "word_pl": "复数",
                "word_third": "第三人称单数",
                "word_past": "过去式",
                "word_done": "过去分词",
                "word_ing": "现在分词",
            }
            exchange_output = ""
            for skey in exchange:
                if skey in type_map:
                    print(
                        exchange_output
                        + f"{type_map[skey]}：[[red]{exchange[skey][0]}[/]]",
                        end="  ",
                    )
            print(exchange_output)

        # if "stems_affixes" in message:
        #     for stems_affixes in message["stems_affixes"]:
        #         print()
        #         print(
        #             f"{stems_affixes['type']}：[bold red]{stems_affixes['type_value']}[/]  {stems_affixes['type_exp']}"
        #         )
        #         print()
        #         for word_part in stems_affixes["word_parts"]:
        #             print(f"[bold grey70]{word_part['word_part']}[/]")
        #             count = 1
        #             for _stems_affixes in word_part["stems_affixes"]:
        #                 print(
        #                     f"    {_stems_affixes['value_en']}：{_stems_affixes['value_cn']}"
        #                 )
        #                 print(f"    [grey70]{_stems_affixes['word_buile']}[/]")
        #                 if count >= 2:
        #                     break
        #                 count = count + 1
        with console.status("[bold green]playing ...") as status:
            while not self.play_finished:
                time.sleep(0.1)


if __name__ == "__main__":
    t = ICibaTranslate()
    t.translate_print("Feb")
