select SUM(s.Stoc*s.Pret_cu_amanuntul) from stocuri s where s.Cod_gestiune='700'
and s.Comanda='1800319125811' and s.Stoc>0
