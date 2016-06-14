SELECT * FROM efecte e where e.Nr_efect like '330104[1-4]'

SELECT p.efect,c.Denumire_cont,* 
FROM pozplin p join conturi c on c.Cont=p.Cont
where p.efect like '330104[1-4]'
