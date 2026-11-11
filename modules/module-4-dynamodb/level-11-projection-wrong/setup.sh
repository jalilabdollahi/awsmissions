#!/usr/bin/env bash
set -euo pipefail
source "$AWSMISSIONS_ROOT/scripts/aws_helpers.sh"

aws_local dynamodb create-table --table-name shelfwise-books \
  --attribute-definitions AttributeName=isbn,AttributeType=S AttributeName=category,AttributeType=S AttributeName=price,AttributeType=N \
  --key-schema AttributeName=isbn,KeyType=HASH \
  --global-secondary-indexes \
  'IndexName=category-index,KeySchema=[{AttributeName=category,KeyType=HASH},{AttributeName=price,KeyType=RANGE}],Projection={ProjectionType=KEYS_ONLY}' \
  --billing-mode PAY_PER_REQUEST >/dev/null

blurb="$(python3 -c "print('A long, richly detailed description of the book. ' * 60)")"
add() {
  aws_local dynamodb put-item --table-name shelfwise-books --item \
    "{\"isbn\":{\"S\":\"$1\"},\"category\":{\"S\":\"$2\"},\"price\":{\"N\":\"$3\"},\"title\":{\"S\":\"$4\"},\"author\":{\"S\":\"$5\"},\"blurb\":{\"S\":\"$blurb\"}}"
}
add 978-0-001 poetry 1200 "Salt and Static" "M. Okafor"
add 978-0-002 poetry 1850 "Rooftop Almanac" "L. Brandt"
add 978-0-003 travel 2400 "Rivers of the North" "S. Tanaka"

echo "category-index returns bare keys; the category pages show ISBNs."
