/*
 * Caudium - An extensible World Wide Web server
 * Copyright � 2000-2004 The Caudium Group
 * Copyright � 1994-2001 Roxen Internet Software
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */

/* Bugs by: Per */
string cvs_version = "$Id$";
/*
 * name = "Spanish language plugin ";
 * doc = "Handles the conversion of numbers and dates to spanish. Translated by jordi@lleida.net. You have to restart the server for updates to take effect.";
 */
/* Trans by: jordi@lleida.net */

string month(int num)
{
  return ({ "Enero", "Febrero", "Marzo", "Abril", "Mayo",
	    "Junio", "Julio", "Agosto", "Septiembre", "Octubre",
	    "Noviembre", "Diciembre" })[ num - 1 ];
}

string ordered(int i)
{
    return i+"�";
}

string date(int timestamp, mapping|void m)
{
  mapping t1=localtime(timestamp);
  mapping t2=localtime(time(0));

  if(!m) m=([]);

  if(!(m["full"] || m["date"] || m["time"]))
  {
    if(t1["yday"] == t2["yday"] && t1["year"] == t2["year"])
      return "hoy, "+ ctime(timestamp)[11..15];
  
    if(t1["yday"]+1 == t2["yday"] && t1["year"] == t2["year"])
      return "ayer, "+ ctime(timestamp)[11..15];
  
    if(t1["yday"]-1 == t2["yday"] && t1["year"] == t2["year"])
      return "ma�ana, "+ ctime(timestamp)[11..15];
  
    if(t1["year"] != t2["year"])
      return (month(t1["mon"]+1) + " " + (t1["year"]+1900));
    return (month(t1["mon"]+1) + " " + ordered(t1["mday"]));
  }
  if(m["full"])
    return ctime(timestamp)[11..15]+", "
	+ t1["mday"] + " de "  + month(t1["mon"]+1)
      	+ " de " +(t1["year"]+1900);

  if(m["date"])
    return t1["mday"] + " de "  + month(t1["mon"]+1)
      	+ " de " +(t1["year"]+1900);

  if(m["time"])
    return ctime(timestamp)[11..15];
}


string number(int num)
{
  if(num<0)
    return "minus "+number(-num);
  switch(num)
  {
   case 0:  return "";
   case 1:  return "uno";
   case 2:  return "dos";
   case 3:  return "tres";
   case 4:  return "cuatro";
   case 5:  return "cinco";
   case 6:  return "seis";
   case 7:  return "siete";
   case 8:  return "ocho";
   case 9:  return "nueve";
   case 10: return "diez";
   case 11: return "once";
   case 12: return "doce";
   case 13: return "trece";
   case 14: return "catorce";
   case 15: return "quince";
   case 16: return "dieciseis";
   case 17: return "diecisiete";
   case 18: return "dieciocho";
   case 19: return "diecinueve";
   case 20: return "veinte";
   case 30: return "treninta";
   case 40: return "cuarenta";
   case 50: return "cincuenta";
   case 60: return "sesenta";
   case 70: return "setenta";
   case 80: return "ochenta";
   case 90: return "noventa";
   case 21..29: 
	return "veinti"+number(num-20);
   case 31..39: case 41..49:
   case 51..59: case 61..69: case 71..79: 
   case 81..89: case 91..99:  
     return number((num/10)*10)+ " y " +number(num%10);
   case 100..199: return "ciento "+number(num%100);
   case 200..999: return number(num/100)+" cientos "+number(num%100);
   case 1000..1999: return "mil "+number(num%1000);
   case 2000..999999: return number(num/1000)+" mil "+number(num%1000);

   case 1000000..1999999: 
     return "un millon "+number(num%1000000);

   case 2000000..999999999: 
     return number(num/1000000)+" millones "+number(num%1000000);

   default:
    return "muchisimo";
  }
}

string day(int num)
{
  return ({ "Domingo","Lunes","Martes","Miercoles",
	    "Jueves","Viernes","Sabado" })[ num - 1 ];
}

array aliases()
{
  return ({ "es", "esp", "spanish" });
}



