#!/bin/bash

# ฟังก์ชันพิมพ์ข้อความกึ่งกลางจอ
center_echo() {
    local termwidth=$(tput cols)
    local text="$*"
    local textlength=${#text}
    if (( textlength >= termwidth )); then
        echo "$text"
    else
        local padding=$(( (termwidth - textlength) / 2 ))
        printf "%*s%s\n" $padding "" "$text"
    fi
}

while true; do
  clear
  center_echo "== 🐾 สำนักหวยแมวดำ 🐈‍⬛ =="
  center_echo " /\\_/\\ "
  center_echo "( o.o )"
  center_echo " > ^ < "
  echo
  echo "== 📮 ระบบตรวจหวย สำนักแมวดำ =="

  # ตรวจเลขสลาก ต้องมี 6 หลักเท่านั้น
  while true; do
    read -p "🔢 ใส่เลขสลาก (6 หลัก): " number
    if [[ "$number" =~ ^[0-9]{6}$ ]]; then
      break
    else
      echo "❌ กรุณาใส่เลขสลากให้ถูกต้อง (ต้องมี 6 หลักเป็นตัวเลขเท่านั้น)"
    fi
  done

  read -p "📅 วันออกรางวัล (เช่น 1 หรือ 16 หรือวันอื่น ๆ): " day
  read -p "🗓️ เดือน (1-12): " month
  read -p "📆 ปี พ.ศ. (เช่น 2567): " year

  # แปลงวันเดือนให้เป็น 2 หลัก
  day=$(printf "%02d" "$day")
  month=$(printf "%02d" "$month")
  year_ad=$((year - 543))

  # กำหนดชื่อไฟล์ cache
  cache_file="lotto_${year_ad}${month}${day}.json"

  echo
  echo "🔍 กำลังตรวจสอบรางวัล..."

  # โหลดข้อมูลจากไฟล์ถ้ามี ไม่งั้นดึงจาก API และบันทึก
  if [[ -f "$cache_file" ]]; then
    echo "📂 โหลดข้อมูลจากไฟล์ $cache_file"
    json=$(cat "$cache_file")
  else
    echo "🌐 ดึงข้อมูลจาก API แล้วบันทึกลงไฟล์ $cache_file"
    json=$(curl -s -X POST -H "Content-Type: application/json" \
      -d "{\"date\":\"$day\",\"month\":\"$month\",\"year\":\"$year_ad\"}" \
      https://www.glo.or.th/api/checking/getLotteryResult)
    
    # ตรวจว่ามีข้อมูลก่อนบันทึก
    has_data=$(echo "$json" | jq -r '.response.result.data? != null')
    if [[ "$has_data" == "true" ]]; then
      echo "$json" > "$cache_file"
    else
      echo "📭 งวดนี้ยังไม่มีข้อมูล หรือหวยยังไม่ออก"
      # รอให้กดปุ่มก่อนจะเริ่มใหม่
      read -n 1 -s -r -p "กด Y เพื่อตรวจหวยอีกครั้ง, หรือปุ่มอื่นเพื่อออก..." key
      echo
      key_lower=$(echo "$key" | tr '[:upper:]' '[:lower:]')
      [[ "$key_lower" == "y" ]] || break
      continue
    fi
  fi

  # ฟังก์ชันแปลงชื่อรางวัลเป็นไทย
  prize_name_th() {
    case "$1" in
      first) echo "รางวัลที่ 1" ;;
      second) echo "รางวัลที่ 2" ;;
      third) echo "รางวัลที่ 3" ;;
      fourth) echo "รางวัลที่ 4" ;;
      fifth) echo "รางวัลที่ 5" ;;
      *) echo "$1" ;;
    esac
  }

  # ฟังก์ชันตรวจรางวัลหลัก
  check_prize() {
    local prize_name="$1"
    local numbers=$(echo "$json" | jq -r ".response.result.data.${prize_name}.number[].value")
    local prize_th=$(prize_name_th "$prize_name")
    for n in $numbers; do
      if [[ "$n" == "$number" ]]; then
        if [[ "$prize_name" == "first" ]]; then
          echo "🎊 ยินดีด้วย! คุณถูกรางวัลที่ 1 เตรียมตัวไปกองสลากได้เลย!"
        else
          echo "🎉 ถูกรางวัล: $prize_th"
        fi
      fi
    done
  }

  check_prize "first"
  check_prize "second"
  check_prize "third"
  check_prize "fourth"
  check_prize "fifth"

  # ตรวจเลขหน้า 3 ตัว
  for n in $(echo "$json" | jq -r '.response.result.data.last3f.number[].value'); do
    if [[ "${number:0:3}" == "$n" ]]; then
      echo "🎉 ถูกรางวัลเลขหน้า 3 ตัว ($n) 	4,000 บาท"
    fi
  done

  # ตรวจเลขท้าย 3 ตัว
  for n in $(echo "$json" | jq -r '.response.result.data.last3b.number[].value'); do
    if [[ "${number:3:3}" == "$n" ]]; then
      echo "🎉 ถูกรางวัลเลขท้าย 3 ตัว ($n) 	4,000 บาท"
    fi
  done

  # ตรวจเลขท้าย 2 ตัว
  for n in $(echo "$json" | jq -r '.response.result.data.last2.number[].value'); do
    if [[ "${number:4:2}" == "$n" ]]; then
      echo "🎉 ถูกรางวัลเลขท้าย 2 ตัว ($n)  2,000 บาท"
    fi
  done

  # ตรวจรางวัลข้างเคียงรางวัลที่ 1
  for n in $(echo "$json" | jq -r '.response.result.data.near1.number[].value'); do
    if [[ "$n" == "$number" ]]; then
      echo "🎉 ถูกรางวัลข้างเคียงรางวัลที่ 1 100,000 บาท"
    fi
  done

  # ตรวจว่าถูกรางวัลอะไรเลยหรือไม่
  match=$(echo "$json" | jq -r --arg num "$number" --arg first3 "${number:0:3}" --arg last3 "${number:3:3}" --arg last2 "${number:4:2}" '
    .response.result.data |
    .. | .? // empty |
    select(
      (.value? == $num) or
      (.value? == $first3) or
      (.value? == $last3) or
      (.value? == $last2)
    )
  ')
  if [[ -z "$match" ]]; then
    echo "💸 เสียใจด้วย... โดนหวยแดกเรียบร้อยแล้ว เจอกันงวดหน้า"
  fi

  echo
  read -n 1 -s -r -p "กด Y เพื่อตรวจหวยอีกครั้ง, หรือปุ่มอื่นเพื่อออก..." key
  echo
  key_lower=$(echo "$key" | tr '[:upper:]' '[:lower:]')
  [[ "$key_lower" == "y" ]] || break
done