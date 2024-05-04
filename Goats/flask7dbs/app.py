"""
This file creates all the routes for the different pages
Primary Source Code writer: Chris
Last updated: 4/25/24
"""

"""
This is an example Flask | Python | Psycopg2 | PostgreSQL
application that connects to the 7dbs database from Chapter 2 of
_Seven Databases in Seven Weeks Second Edition_
by Luc Perkins with Eric Redmond and Jim R. Wilson.
The CSC 315 Virtual Machine is assumed.

John DeGood
degoodj@tcnj.edu
The College of New Jersey
Spring 2020

----

One-Time Installation

You must perform this one-time installation in the CSC 315 VM:

# install python pip and psycopg2 packages
sudo pacman -Syu
sudo pacman -S python-pip python-psycopg2 python-flask

----

Usage

To run the Flask application, simply execute:

export FLASK_APP=app.py 
flask run
# then browse to http://127.0.0.1:5000/

----

References

Flask documentation:  
https://flask.palletsprojects.com/  

Psycopg documentation:
https://www.psycopg.org/

This example code is derived from:
https://www.postgresqltutorial.com/postgresql-python/
https://scoutapm.com/blog/python-flask-tutorial-getting-started-with-flask
https://www.geeksforgeeks.org/python-using-for-loop-in-flask/
"""

import psycopg2
from config import config
from flask import Flask, render_template, request

# Connect to the PostgreSQL database server
def connect(query):
    conn = None
    try:
        # read connection parameters
        params = config()
 
        # connect to the PostgreSQL server
        print('Connecting to the %s database...' % (params['database']))
        conn = psycopg2.connect(**params)
        print('Connected.')
      
        # create a cursor
        cur = conn.cursor()
        
        # execute a query using fetchall()
        cur.execute(query)
        rows = cur.fetchall()

        # close the communication with the PostgreSQL
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    finally:
        if conn is not None:
            conn.close()
            print('Database connection closed.')
    # return the query result from fetchall()
    return rows
 
# app.py
app = Flask(__name__)

@app.route("/")
def home():
    return render_template('home.html')

@app.route("/home_graph")
def home_graph():
    return render_template('home_graph.html')

# serve form web page
@app.route("/deaths_form")
def form():
    return render_template('my-form.html')

@app.route("/weight_form")
def weight_form():
    return render_template('weight-input.html')

@app.route('/graph')
def deaths_per_year_graph():
    query_result = connect("SELECT year, COUNT(*) AS num_deaths FROM DeathAge GROUP BY year ORDER BY year;")
    data = [{'year': row[0], 'num_deaths': row[1]} for row in query_result]
    return render_template('graph.html', data=data)

@app.route('/summer_graph')
def summer_deaths_per_year_graph():
    query_result = connect("SELECT year, COUNT(*) AS num_deaths FROM DeathSummer GROUP BY year ORDER BY year;")
    data = [{'year': row[0], 'num_deaths': row[1]} for row in query_result]
    return render_template('summer_graph.html', data=data)

@app.route('/fall_graph')
def fall_deaths_per_year_graph():
    query_result = connect("SELECT year, COUNT(*) AS num_deaths FROM DeathFall GROUP BY year ORDER BY year;")
    data = [{'year': row[0], 'num_deaths': row[1]} for row in query_result]
    return render_template('fall_graph.html', data=data)

@app.route('/winter_graph')
def winter_deaths_per_year_graph():
    query_result = connect("SELECT year, COUNT(*) AS num_deaths FROM DeathWinter GROUP BY year ORDER BY year;")
    data = [{'year': row[0], 'num_deaths': row[1]} for row in query_result]
    return render_template('winter_graph.html', data=data)


@app.route('/spring_graph')
def spring_deaths_per_year_graph():
    query_result = connect("SELECT year, COUNT(*) AS num_deaths FROM DeathSpring GROUP BY year ORDER BY year;")
    data = [{'year': row[0], 'num_deaths': row[1]} for row in query_result]
    return render_template('spring_graph.html', data=data)

@app.route('/weaning_weight_graph')
def weaning_weight_graph():
    query_result = connect("SELECT * FROM WeaningWeight ORDER BY CAST(birthweight AS DECIMAL(4,1));")
    data = [{'birthweight': row[1], 'weight': row[2]} for row in query_result]
    return render_template('weight_graph.html', data=data)  

@app.route('/winter_weight_graph')
def winter_weight_graph():
    query_result = connect("SELECT * FROM WinterWeight ORDER BY CAST(birthweight AS DECIMAL(4,1));")
    data = [{'birthweight': row[1], 'weight': row[2]} for row in query_result]
    return render_template('winter_weight_graph.html', data=data)   

@app.route('/sale_weight_graph')
def sale_weight_graph():
    query_result = connect("SELECT * FROM SaleWeight ORDER BY CAST(birthweight AS DECIMAL(4,1));")
    data = [{'birthweight': row[1], 'weight': row[2]} for row in query_result]
    return render_template('sale_weight_graph.html', data=data) 

# handle venue POST and serve result web page
@app.route('/deathyear', methods=['POST'])
def deathyear():
    rows = connect('SELECT tag, date, age FROM DeathAge WHERE year = ' + request.form['year'] + ';')
    heads = ['Tag ID', 'Date', 'Death Age']
    return render_template('my-result.html', rows=rows, heads=heads)
    
@app.route('/compare_deaths')
def compare_deaths():
    rows = connect('SELECT * FROM DeathYear;')
    heads = ['Year', 'Total Deaths', 'Spring Deaths', 'Summer Deaths', 'Fall Deaths', 'Winter Deaths']
    return render_template('compare_deaths.html', rows=rows, heads=heads)

@app.route('/compare_births')
def compare_births():
    rows = connect('SELECT * FROM BWperYear;')
    heads = ['Year', 'Average birthweight']
    return render_template('compare_births.html', rows=rows, heads=heads)

@app.route('/compare_weights')
def compare_weights():
    rows = connect('SELECT * FROM BirthWeight;')
    heads = ['Birthweight', 'Average Weaning Weight', 'Average Winter Weight', 'Average Sale Weight']
    return render_template('compare_weights.html', rows=rows, heads=heads)

@app.route('/weight', methods=['POST'])
def weight():
    rows = connect('SELECT * FROM WeightType WHERE CAST(birthweight AS DECIMAL (4,1)) = ' + request.form['birthweight'] + ';')
    heads = ['Tag ID', 'Birth Weight', 'Weaning Weight', 'Winter Weight', 'Sale Weight']
    return render_template('my-result.html', rows=rows, heads=heads)

# handle query POST and serve result web page
#@app.route('/query-handler', methods=['POST'])
#def query_handler():
#    rows = connect(request.form['query'])
#    return render_template('my-result.html', rows=rows)

if __name__ == '__main__':
    app.run(debug = True)
