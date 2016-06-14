select * from pozcon p where p.Contract='9810701' and p.Subunitate='1' and p.Cod='efc-t12'
select * from stocuri s where s.Stoc>=0.001 and Cod='efc-t12' and s.Cod_gestiune='211'
select * from pozdoc p where p.Tip='ap' and p.Cod='efc-t12' and p.Contract='9810701'