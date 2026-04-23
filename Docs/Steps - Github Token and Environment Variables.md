# Steps - Github Token and Environment Variables
- The app uses the .env.docker variables for Github repository encryption key and GO CD Server Administrative password.
## To get the current Github ENV_ENCRYPTION_KEY variable:
```powershell
.\Scripts\get-gh-variable.ps1  
```
- Check the .env.docker file if the GITHUB_TOKEN is the same as the gh value you got.
- The GOCD_ADMIN_PASSWORD value may or may not be the same with the value of the GITHUB_TOKEN but for security's sake, I make it a good practice to change it too when I change the value of GITHUB_TOKEN.
- The token we use is is the 30-day gocd-server token located here:
```url
    https://github.com/settings/tokens/2739118787
```
- After regenerating the token, replace the ENV_ENCRYPTION_KEY value.
- The repository variables are located here:
```url
    https://github.com/xmione/gocd-server/settings/variables/actions
```    

## To get the current GO CD Server Administrator password:
```powershell
.\Scripts\getadminpassword.ps1  
```