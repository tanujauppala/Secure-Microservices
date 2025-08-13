import React, { useEffect, useState } from "react";
import './style.css';


function App() {
  const [tasks, setTasks] = useState([]);
  const [input, setInput] = useState("");

  useEffect(() => {
    fetch("/api/tasks")
      .then(res => res.json())
      .then(data => setTasks(data))
      .catch(err => console.error("Error fetching tasks:", err));
  }, []);

  const handleAddTask = () => {
    fetch("/api/tasks", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ task: input })
    })
      .then(res => res.json())
      .then(newTask => {
        setTasks([...tasks, newTask]);
        setInput("");
      });
  };

  return (
    <div style={{ padding: 40 }}>
      <h1>Task Manager</h1>
      <input
        type="text"
        value={input}
        onChange={e => setInput(e.target.value)}
        placeholder="Enter a task"
      />
      <button onClick={handleAddTask}>Add Task</button>
      <ul>
        {tasks.map((t, i) => <li key={i}>{t.task}</li>)}
      </ul>
    </div>
  );
}

export default App;
