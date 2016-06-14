select top 1 *
				from stocuri s
				where subunitate='1' and cod='EFC-H34' --and tip_gestiune=@TipG /* anulat pt. ca in lista gestiuni pot fi mai multe tipuri */
				and charindex(';'+RTrim(s.cod_gestiune)+';',';212.1;')>0 
				and (s.Tip_gestiune<>'A' or abs(s.Pret_cu_amanuntul-1.300000000000000e+001)<0.0009)
				
