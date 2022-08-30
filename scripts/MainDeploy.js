const { deployPotato } = require("./03-deploy-CringeToken");
async function main() {
  await deployCringeToken();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
