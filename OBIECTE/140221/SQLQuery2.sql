SELECT 
pz.TVA_deductibil,
round(pz.cantitate*(pz.pret_cu_amanuntul/(1+convert(decimal(12,3),pz.tva_neexigibil)/100)-pz.pret_de_stoc),2) as AD,
pz.Pret_cu_amanuntul,
pz.Adaos,
pz.Pret_vanzare,
convert(DECIMAL(17, 5), pz.Pret_cu_amanuntul / (1.00 + isnull(pz.TVA_neexigibil, 0) / 100)),
pz.pret_cu_amanuntul/(1+convert(decimal(12,3),pz.tva_neexigibil)/100),
pz.TVA_neexigibil,* from pozdoc pz where pz.Tip='TE' and pz.Numar='NT10001' and pz.Data='2014-01-30'